import 'package:flutter/material.dart';

class AppTheme {
  // Primary brand color used across AppBars and accents
  static const Color primary = Color(0xFF6A1B9A);

  // Neutral surface/background color (cards, bars, etc.)
  static const Color backgroundColor = Colors.white;

  // Secondary text/icon color for unselected/disabled items
  static const Color secondaryText = Colors.grey;

  // Accent colors used for light decorative gradients/sections
  static const Color accent = Color(0xFFE1BEE7); // light purple
  static const Color accentLight = Color(0xFFF3E5F5); // even lighter purple

  // Shadow base color
  static const Color shadowColor = Colors.purpleAccent;

  // Background gradient used on all major screens
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFD6B5E5), Color(0xFFB19CD9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Consistent soft shadow used for cards
  static List<BoxShadow> get cardShadows => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  // Standard card decoration
  static BoxDecoration cardBoxDecoration({double radius = 14, Color color = Colors.white}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: cardShadows,
    );
  }

  // Helper to build a consistent AppBar
  static PreferredSizeWidget buildAppBar(String title, {List<Widget>? actions}) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: actions,
    );
  }
}
