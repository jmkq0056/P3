import 'package:flutter/material.dart';

// App Colors
class AppColors {
  // Primary colors
  static const Color primaryDark = Color(0xFF1F1F1F);
  static const Color primaryLight = Color(0xFFF7F7F7);
  
  // Accent colors
  static const Color accent = Color(0xFF00A3FF);
  static const Color accentSecondary = Color(0xFF00D0C3);
  
  // Feature colors
  static const Color steps = Color(0xFF3385FF);
  static const Color calories = Color(0xFFFF6B6B);
  static const Color water = Color(0xFF00A3FF);
  static const Color sleep = Color(0xFF9C5FFF);
  static const Color weight = Color(0xFF4CAF50);
  
  // Prayer colors
  static const Color prayer = Color(0xFF6D28D9);        // Deep violet for prayer main
  static const Color prayerGlow = Color(0xFFE0B3FF);    // Light purple for glow effect
  static const Color prayerCompleted = Color(0xFF34D399); // Mint green for completed prayers
  static const Color prayerMissed = Color(0xFFF87171);   // Coral red for missed prayers
  static const Color prayerUpcoming = Color(0xFFFACC15); // Warm yellow for upcoming prayers
  static const Color prayerCurrent = Color(0xFF6D28D9);  // Primary violet for current prayer
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFAA00);
  static const Color error = Color(0xFFFF5252);
  
  // Text colors
  static const Color textDark = Color(0xFF121212);
  static const Color textLight = Color(0xFFF2F2F2);
  static const Color textGrey = Color(0xFF757575);
}

// App dimensions
class AppDimensions {
  // Margins and paddings
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;
  static const double s56 = 56.0;
  static const double s64 = 64.0;
  
  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  
  // Border radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
}

// Text styles
class AppTextStyles {
  static const String fontFamily = 'SF Pro Display';
  
  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
  );
  
  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
  );
  
  // Button text
  static const TextStyle button = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  // Label text
  static const TextStyle label = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
}

// Animation durations
class AppDurations {
  static const Duration shortest = Duration(milliseconds: 150);
  static const Duration short = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration long = Duration(milliseconds: 500);
} 