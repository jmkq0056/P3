import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme class that defines the visual identity of the app
class AppTheme {
  // Color Palette: "Energetic Bloom"
  static const Color primaryColor = Color(0xFF6D28D9); // Deep Violet/Grape
  static const Color primaryColorLight = Color(0xFF8B5CF6); // Lighter violet for dark mode
  static const Color secondaryColor1 = Color(0xFFF87171); // Coral Red
  static const Color secondaryColor2 = Color(0xFF34D399); // Mint Green
  static const Color backgroundLight = Color(0xFFF3F4F6); // Light Gray
  static const Color backgroundWhite = Color(0xFFFFFFFF); // White
  static const Color textColor = Color(0xFF1F2937); // Dark Charcoal
  static const Color textColorDark = Color(0xFFE5E7EB); // Light gray for dark mode text
  
  // Additional colors for functional elements
  static const Color successColor = Color(0xFF10B981); // Green
  static const Color warningColor = Color(0xFFFCD34D); // Yellow
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color infoColor = Color(0xFF3B82F6); // Blue
  
  // Surface colors and variants
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF121212); // Darker background for dark mode
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E1E); // Darker card for better contrast
  
  // Font sizes
  static const double fontSizeXSmall = 12.0;
  static const double fontSizeSmall = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeXXLarge = 24.0;
  static const double fontSizeHeading = 32.0;
  
  // Border radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;
  
  /// Returns the light theme data
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor1,
        tertiary: secondaryColor2,
        background: backgroundLight,
        surface: surfaceLight,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onBackground: textColor,
        onSurface: textColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceLight,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: fontSizeLarge,
          color: textColor,
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textColor.withOpacity(0.7),
        indicatorColor: primaryColor,
        labelStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: fontSizeSmall,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.normal,
          fontSize: fontSizeSmall,
        ),
      ),
      cardTheme: CardTheme(
        color: cardLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: fontSizeMedium,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: fontSizeMedium,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: fontSizeMedium,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium, 
          vertical: spacingMedium,
        ),
        hintStyle: GoogleFonts.inter(
          color: textColor.withOpacity(0.5),
          fontSize: fontSizeMedium,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: fontSizeHeading,
          color: textColor,
        ),
        displayMedium: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: fontSizeXXLarge,
          color: textColor,
        ),
        displaySmall: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: fontSizeXLarge,
          color: textColor,
        ),
        headlineMedium: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          fontSize: fontSizeLarge,
          color: textColor,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          fontSize: fontSizeMedium,
          color: textColor,
        ),
        bodyLarge: GoogleFonts.inter(
          fontWeight: FontWeight.normal,
          fontSize: fontSizeMedium,
          color: textColor,
        ),
        bodyMedium: GoogleFonts.inter(
          fontWeight: FontWeight.normal,
          fontSize: fontSizeSmall,
          color: textColor,
        ),
        labelLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: fontSizeMedium,
          color: textColor,
        ),
      ),
      iconTheme: const IconThemeData(
        color: textColor,
        size: 24,
      ),
    );
  }

  /// Returns the dark theme data
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primaryColorLight, // Brighter primary color for dark mode
        secondary: secondaryColor1,
        tertiary: secondaryColor2,
        background: surfaceDark,
        surface: cardDark,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onBackground: textColorDark,
        onSurface: textColorDark,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: surfaceDark,
      appBarTheme: AppBarTheme(
        backgroundColor: cardDark,
        foregroundColor: textColorDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: fontSizeLarge,
          color: textColorDark,
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primaryColorLight,
        unselectedLabelColor: textColorDark.withOpacity(0.7),
        indicatorColor: primaryColorLight,
        labelStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: fontSizeSmall,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.normal,
          fontSize: fontSizeSmall,
        ),
      ),
      cardTheme: CardTheme(
        color: cardDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColorLight, // Brighter color for buttons
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: fontSizeMedium,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryColor2, // Mint green is good contrast for dark mode
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: fontSizeMedium,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColorDark,
          side: const BorderSide(color: primaryColorLight), // Brighter border
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: fontSizeMedium,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryColorLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium, 
          vertical: spacingMedium,
        ),
        hintStyle: GoogleFonts.inter(
          color: textColorDark.withOpacity(0.5),
          fontSize: fontSizeMedium,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: fontSizeHeading,
          color: textColorDark,
        ),
        displayMedium: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: fontSizeXXLarge,
          color: textColorDark,
        ),
        displaySmall: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: fontSizeXLarge,
          color: textColorDark,
        ),
        headlineMedium: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          fontSize: fontSizeLarge,
          color: textColorDark,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          fontSize: fontSizeMedium,
          color: textColorDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontWeight: FontWeight.normal,
          fontSize: fontSizeMedium,
          color: textColorDark,
        ),
        bodyMedium: GoogleFonts.inter(
          fontWeight: FontWeight.normal,
          fontSize: fontSizeSmall,
          color: textColorDark,
        ),
        labelLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: fontSizeMedium,
          color: textColorDark,
        ),
      ),
      iconTheme: IconThemeData(
        color: textColorDark,
        size: 24,
      ),
    );
  }

  /// Returns the current theme based on the provided brightness
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.light ? lightTheme() : darkTheme();
  }

  /// Applies the theme to the app
  static ThemeData apply({required Brightness brightness}) {
    return getTheme(brightness);
  }
} 