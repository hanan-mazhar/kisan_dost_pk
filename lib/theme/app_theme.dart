import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors — richer, deeper palette
  static const Color primaryGreen   = Color(0xFF1A7A4A);
  static const Color lightGreen     = Color(0xFF25A96A);
  static const Color accentGreen    = Color(0xFF4CC88A);
  static const Color darkGreen      = Color(0xFF0D5C35);
  static const Color deepGreen      = Color(0xFF0A3D24);
  static const Color amber          = Color(0xFFFFB300);
  static const Color lightAmber     = Color(0xFFFFD54F);
  static const Color background     = Color(0xFFF2F4F0);
  static const Color cardWhite      = Color(0xFFFFFFFF);
  static const Color surfaceLight   = Color(0xFFF8FAF8);
  static const Color textDark       = Color(0xFF111827);
  static const Color textMedium     = Color(0xFF6B7280);
  static const Color textLight      = Color(0xFFB0BAC9);
  static const Color divider        = Color(0xFFE5E9E6);
  static const Color errorRed       = Color(0xFFDC2626);
  static const Color successGreen   = Color(0xFF16A34A);
  static const Color warningOrange  = Color(0xFFEA580C);
  static const Color infoBluee      = Color(0xFF2563EB);

  // Status Colors
  static const Color pendingColor   = Color(0xFFFEF3C7);
  static const Color pendingText    = Color(0xFFD97706);
  static const Color acceptedColor  = Color(0xFFD1FAE5);
  static const Color acceptedText   = Color(0xFF065F46);
  static const Color deliveredColor = Color(0xFFDBEAFE);
  static const Color deliveredText  = Color(0xFF1D4ED8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: amber,
        surface: background,
        background: background,
        error: errorRed,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800, color: textDark),
        displayMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: textDark),
        headlineLarge: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: textDark),
        headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
        headlineSmall: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
        titleLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
        titleMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: textDark),
        bodyLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: textDark),
        bodyMedium: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: textMedium),
        labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: cardWhite, letterSpacing: 0.3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: cardWhite,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: primaryGreen, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: divider, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorRed),
        ),
        hintStyle: GoogleFonts.poppins(color: textLight, fontSize: 14),
        labelStyle: GoogleFonts.poppins(color: textMedium, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: divider, width: 0.8),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardWhite,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: textDark),
        iconTheme: const IconThemeData(color: textDark),
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardWhite,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textMedium,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: background,
        selectedColor: primaryGreen.withOpacity(0.12),
        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      scaffoldBackgroundColor: background,
      dividerTheme: const DividerThemeData(color: divider, thickness: 0.8),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: GoogleFonts.poppins(fontSize: 14),
      ),
    );
  }

  // Gradients
  static BoxDecoration get greenGradient => const BoxDecoration(
    gradient: LinearGradient(
      colors: [deepGreen, primaryGreen, lightGreen],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: [0.0, 0.55, 1.0],
    ),
  );

  static BoxDecoration get lightGreenGradient => BoxDecoration(
    gradient: LinearGradient(
      colors: [primaryGreen.withOpacity(0.08), accentGreen.withOpacity(0.04)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(18),
  );

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardWhite,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: divider, width: 0.8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 12,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
    color: cardWhite,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: primaryGreen.withOpacity(0.08),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}
