import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - Modern appetizing palette
  static const Color tachaoRed = Color(0xFFE31E24);
  static const Color tachaoRedDark = Color(0xFFB71C1C);
  static const Color honeyGold = Color(0xFFFFB300);

  // Light theme specific
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color greyText = Color(0xFF666666);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color borderGrey = Color(0xFFE0E0E0);

  // Dark theme specific
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkInputBg = Color(0xFF2A2A2A);

  // Adaptive helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? darkBackground : Colors.white;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurface : Colors.white;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : darkText;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : greyText;

  static Color divider(BuildContext context) =>
      isDark(context) ? darkBorder : borderGrey;

  static Color inputBg(BuildContext context) =>
      isDark(context) ? darkInputBg : lightGrey;

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorder : borderGrey;

  static Color shadow(BuildContext context) =>
      isDark(context) ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04);

  static Color cardBg(BuildContext context) =>
      isDark(context) ? darkSurface : Colors.white;

  static ThemeData get _baseTheme => ThemeData(
        useMaterial3: true,
        primaryColor: tachaoRed,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: tachaoRed,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  static ThemeData get lightTheme => _baseTheme.copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: tachaoRed,
          primary: tachaoRed,
          secondary: honeyGold,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Colors.white,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
          displayMedium: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: darkText,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: greyText,
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: greyText,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: lightGrey,
          selectedColor: tachaoRed,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: darkText,
          ),
          secondaryLabelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide.none,
          ),
        ),
      );

  static ThemeData get darkTheme => _baseTheme.copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: tachaoRed,
          primary: tachaoRed,
          secondary: honeyGold,
          surface: darkSurface,
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: darkBackground,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkTextPrimary,
          ),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: darkTextPrimary,
          ),
          displayMedium: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: darkTextPrimary,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: darkTextPrimary,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkTextPrimary,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: darkTextPrimary,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: darkTextSecondary,
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: darkTextSecondary,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: darkInputBg,
          selectedColor: tachaoRed,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: darkTextPrimary,
          ),
          secondaryLabelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide.none,
          ),
        ),
      );
}
