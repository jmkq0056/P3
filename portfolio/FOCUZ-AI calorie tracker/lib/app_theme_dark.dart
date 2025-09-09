import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

/// Dark mode theme extension of the app theme that applies the "Energetic Bloom" palette
/// to dark backgrounds and surfaces while maintaining brand consistency.
class AppThemeDark {
  // Dark mode specific colors
  static const Color backgroundDark = Color(0xFF121212); // Very dark background
  static const Color cardDark = Color(0xFF1E1E1E); // Slightly lighter surface
  static const Color textColorDark = Color(0xFFE5E7EB); // Light gray for text
  
  // Use slightly desaturated/lightened versions of accent colors for better contrast
  static const Color primaryColorDark = Color(0xFF8B5CF6); // Lighter violet
  static const Color secondaryColor1Dark = Color(0xFFFF8A8A); // Lighter coral
  static const Color secondaryColor2Dark = Color(0xFF4AE3AD); // Lighter mint
  
  /// Returns the dark theme data
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColorDark,
        secondary: secondaryColor1Dark,
        tertiary: secondaryColor2Dark,
        background: backgroundDark,
        surface: cardDark,
        error: AppTheme.errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onBackground: textColorDark,
        onSurface: textColorDark,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: AppBarTheme(
        backgroundColor: cardDark,
        foregroundColor: textColorDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: AppTheme.fontSizeLarge,
          color: textColorDark,
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primaryColorDark,
        unselectedLabelColor: textColorDark.withOpacity(0.7),
        indicatorColor: primaryColorDark,
        labelStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: AppTheme.fontSizeSmall,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.normal,
          fontSize: AppTheme.fontSizeSmall,
        ),
      ),
      cardTheme: CardTheme(
        color: cardDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        shadowColor: Colors.black.withOpacity(0.5), // More noticeable shadows
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColorDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLarge,
            vertical: AppTheme.spacingMedium,
          ),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: AppTheme.fontSizeMedium,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColorDark,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: AppTheme.fontSizeMedium,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColorDark,
          side: BorderSide(color: primaryColorDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLarge,
            vertical: AppTheme.spacingMedium,
          ),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: AppTheme.fontSizeMedium,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: primaryColorDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium, 
          vertical: AppTheme.spacingMedium,
        ),
        hintStyle: GoogleFonts.inter(
          color: textColorDark.withOpacity(0.5),
          fontSize: AppTheme.fontSizeMedium,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: AppTheme.fontSizeHeading,
          color: textColorDark,
        ),
        displayMedium: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: AppTheme.fontSizeXXLarge,
          color: textColorDark,
        ),
        displaySmall: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: AppTheme.fontSizeXLarge,
          color: textColorDark,
        ),
        headlineMedium: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          fontSize: AppTheme.fontSizeLarge,
          color: textColorDark,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          fontSize: AppTheme.fontSizeMedium,
          color: textColorDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontWeight: FontWeight.normal,
          fontSize: AppTheme.fontSizeMedium,
          color: textColorDark,
        ),
        bodyMedium: GoogleFonts.inter(
          fontWeight: FontWeight.normal,
          fontSize: AppTheme.fontSizeSmall,
          color: textColorDark,
        ),
        labelLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: AppTheme.fontSizeMedium,
          color: textColorDark,
        ),
      ),
      iconTheme: IconThemeData(
        color: textColorDark,
        size: 24,
      ),
      // Add subtle glow or lighter border to cards for better elevation
      // perception in dark mode
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.1),
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColorDark;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColorDark.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.3);
        }),
      ),
    );
  }
} 