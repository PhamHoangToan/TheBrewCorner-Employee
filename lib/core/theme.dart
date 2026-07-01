import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const brand = Color(0xFF662C21);
  static const brandDark = Color(0xFF3F1A10);
  static const cream = Color(0xFFFEE1BF);
  static const pageBg = Color(0xFFF5EDE8);
  static const textDark = Color(0xFF2D1A0E);
  static const textMuted = Color(0xFF7A5040);
  static const border = Color(0xFFF0E8E4);

  static const amberBg = Color(0xFFFFF3CD);
  static const amberFg = Color(0xFF966006);
  static const greenBg = Color(0xFFDAF1E0);
  static const greenFg = Color(0xFF1E7846);
  static const redBg = Color(0xFFFCE0DC);
  static const redFg = Color(0xFFB02E26);
}

class AppTheme {
  static ThemeData light() {
    final headingFont = GoogleFonts.montserrat();
    final bodyFont = GoogleFonts.lato();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.pageBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        primary: AppColors.brand,
        secondary: AppColors.cream,
        surface: Colors.white,
      ),
      fontFamily: bodyFont.fontFamily,
      textTheme: GoogleFonts.latoTextTheme().copyWith(
        titleLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: AppColors.textDark),
        titleMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: AppColors.textDark),
        titleSmall: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: AppColors.textDark),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headingFont.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.pageBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.brand,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}
